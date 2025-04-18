import * as React from 'react';
import APAvatar from '@components/global/APAvatar';
import ActivityItem from '@components/activities/ActivityItem';
import {Button, H4, LucideIcon, Skeleton} from '@tryghost/shade';
import {handleProfileClick, handleProfileClickRR} from '@utils/handle-profile-click';
import {useFeatureFlags} from '@src/lib/feature-flags';
import {useNavigate, useNavigationStack} from '@tryghost/admin-x-framework';
import {useSuggestedProfilesForUser} from '@hooks/use-activity-pub-queries';

const Recommendations: React.FC = () => {
    const {suggestedProfilesQuery} = useSuggestedProfilesForUser('index', 3);
    const {data: suggestedData, isLoading: isLoadingSuggested} = suggestedProfilesQuery;
    const suggested = suggestedData || Array(3).fill({id: '', name: '', handle: '', avatarUrl: '', bio: '', followerCount: 0, followingCount: 0, followedByMe: false});
    const navigate = useNavigate();
    const {isEnabled} = useFeatureFlags();
    const {resetStack} = useNavigationStack();

    let i = 0;

    const hideClassName = '[@media(max-height:740px)]:hidden';

    return (
        <div className={`border-t border-gray-200 px-3 pt-6 dark:border-gray-950 ${hideClassName}`}>
            <div className='mb-3 flex flex-col gap-0.5'>
                <div className='flex items-center gap-2'>
                    <LucideIcon.Globe className='text-purple-500' size={20} strokeWidth={1.5} />
                    <H4>Follow suggestions</H4>
                </div>
                <span className='text-sm text-gray-700'>
                    Accounts you might be interested in
                </span>
            </div>
            <ul className='grow'>
                {suggested.map((profile) => {
                    const actorId = profile.id;
                    const actorName = profile.name;
                    const actorHandle = profile.handle;
                    const actorAvatarUrl = profile.avatarUrl;
                    let className;
                    switch (i) {
                    case 0:
                        className = '[@media(max-height:740px)]:hidden';
                        break;
                    case 1:
                        className = '[@media(max-height:800px)]:hidden';
                        break;
                    case 2:
                        className = '[@media(max-height:860px)]:hidden';
                        break;
                    }
                    i = i + 1;

                    return (
                        <React.Fragment key={actorId}>
                            <li key={actorId} className={className}>
                                <ActivityItem onClick={() => {
                                    if (isEnabled('ap-routes')) {
                                        handleProfileClickRR(actorHandle, navigate);
                                    } else {
                                        handleProfileClick(actorHandle);
                                    }
                                }}>
                                    {!isLoadingSuggested ? <APAvatar author={
                                        {
                                            icon: {
                                                url: actorAvatarUrl
                                            },
                                            name: actorName,
                                            handle: actorHandle
                                        }
                                    } /> : <Skeleton className='z-10 h-10 w-10' />}
                                    <div className='flex min-w-0  flex-col'>
                                        <span className='block max-w-[190px] truncate font-semibold text-black dark:text-white'>{!isLoadingSuggested ? actorName : <Skeleton className='w-24' />}</span>
                                        <span className='block max-w-[190px] truncate text-sm text-gray-600'>{!isLoadingSuggested ? actorHandle : <Skeleton className='w-40' />}</span>
                                    </div>
                                </ActivityItem>
                            </li>
                        </React.Fragment>
                    );
                })}
            </ul>
            <Button className='p-0 font-medium text-purple' variant='link' onClick={() => {
                resetStack();
                navigate('/explore');
            }}>Find more &rarr;</Button>
        </div>
    );
};

export default Recommendations;
